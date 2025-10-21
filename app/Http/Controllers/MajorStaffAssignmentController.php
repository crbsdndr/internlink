<?php

namespace App\Http\Controllers;

use App\Models\MajorStaffAssignment;
use App\Models\SchoolMajor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class MajorStaffAssignmentController extends Controller
{
    public function index()
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404, 'School context missing.');

        $assignments = DB::table('major_staff_details_view')
            ->where('school_id', $schoolId)
            ->orderBy('major')
            ->paginate(10)
            ->withQueryString();

        return view('major-staff.index', [
            'assignments' => $assignments,
        ]);
    }

    public function create()
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404);

        return view('major-staff.create', $this->formData($schoolId));
    }

    public function store(Request $request)
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404);

        $validated = $this->validatePayload($request, $schoolId);

        MajorStaffAssignment::create([
            'school_id' => $schoolId,
            'supervisor_id' => $validated['supervisor_id'],
            'major' => $validated['major'],
            'major_id' => $validated['major_id'],
        ]);

        return redirect($this->schoolRoute('major-contacts'))->with('status', 'Staff contact assigned successfully.');
    }

    public function edit($school, $id)
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404);

        $assignment = MajorStaffAssignment::where('school_id', $schoolId)->findOrFail($id);

        return view('major-staff.edit', $this->formData($schoolId, $assignment));
    }

    public function update(Request $request, $school, $id)
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404);

        $assignment = MajorStaffAssignment::where('school_id', $schoolId)->findOrFail($id);
        $validated = $this->validatePayload($request, $schoolId, $assignment->id);

        $assignment->fill([
            'supervisor_id' => $validated['supervisor_id'],
            'major' => $validated['major'],
            'major_id' => $validated['major_id'],
        ]);
        $assignment->save();

        return redirect($this->schoolRoute('major-contacts'))->with('status', 'Staff contact updated successfully.');
    }

    public function destroy($school, $id)
    {
        $this->authorizeManage();

        $schoolId = $this->currentSchoolId();
        abort_if(!$schoolId, 404);

        $assignment = MajorStaffAssignment::where('school_id', $schoolId)->findOrFail($id);
        $assignment->delete();

        return redirect($this->schoolRoute('major-contacts'))->with('status', 'Staff contact removed successfully.');
    }

    private function formData(int $schoolId, ?MajorStaffAssignment $assignment = null): array
    {
        $supervisors = DB::table('supervisor_details_view')
            ->select('id', 'name', 'email', 'phone', 'department')
            ->where('school_id', $schoolId)
            ->orderBy('name')
            ->get();

        $majors = SchoolMajor::forSchool($schoolId)->active()->orderBy('name')->get();

        return [
            'assignment' => $assignment,
            'supervisors' => $supervisors,
            'majors' => $majors,
        ];
    }

    private function validatePayload(Request $request, int $schoolId, ?int $assignmentId = null): array
    {
        $validated = $request->validate([
            'major_id' => [
                'required',
                'integer',
                Rule::exists('school_majors', 'id')->where(fn ($query) => $query->where('school_id', $schoolId)),
            ],
            'supervisor_id' => [
                'required',
                'integer',
                Rule::exists('supervisors', 'id')->where(fn ($query) => $query->where('school_id', $schoolId)),
            ],
        ]);

        $major = SchoolMajor::find($validated['major_id']);
        $duplicate = MajorStaffAssignment::where('school_id', $schoolId)
            ->where('major_id', $validated['major_id'])
            ->when($assignmentId, fn ($query) => $query->where('id', '!=', $assignmentId))
            ->exists();

        if ($duplicate) {
            throw ValidationException::withMessages([
                'major_id' => 'A staff contact already exists for this major.',
            ]);
        }

        return [
            'major_id' => (int) $validated['major_id'],
            'supervisor_id' => (int) $validated['supervisor_id'],
            'major' => $major->name,
        ];
    }

    private function authorizeManage(): void
    {
        $role = session('role');
        $allowed = in_array($role, ['developer', 'admin'], true);
        abort_unless($allowed, 403, 'Unauthorized.');
    }
}
